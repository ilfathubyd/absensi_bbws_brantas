<?php

namespace App\Http\Controllers\Website;

use App\Http\Controllers\Controller;
use App\Models\Rapat;
use App\Models\Cabang;
use App\Models\Room;
use App\Models\StatusRapat;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use SimpleSoftwareIO\QrCode\Facades\QrCode;
use App\Models\User;
use App\Notifications\NewMeetingNotification;
use Illuminate\Support\Facades\Notification;

class PicController extends Controller
{
    public function dashboard()
    {
        $user = Auth::user();
        
        // Statistik untuk PIC
        // 1. Menunggu Konfirmasi (Status 3)
        $totalMenunggu = Rapat::where('id_user_pengaju', $user->id_user)
            ->where('id_status', 3)
            ->count();

        // 2. Akan Datang (Status 1 & 4, Tanggal >= Hari ini)
        $totalAkanDatang = Rapat::where('id_user_pengaju', $user->id_user)
            ->whereIn('id_status', [1, 4])
            ->where('tanggal', '>=', \Carbon\Carbon::now()->format('Y-m-d'))
            ->count();

        // 3. Total Pengajuan Saya (Semua status)
        $totalPengajuan = Rapat::where('id_user_pengaju', $user->id_user)->count();
        
        $rapatBaruDibuat = Rapat::with(['room', 'pengaju', 'status'])
            ->where('id_user_pengaju', $user->id_user)
            ->where('created_at', '>=', \Carbon\Carbon::now()->subDays(3))
            ->latest()
            ->get();

        $rapatTigaHariTerakhir = Rapat::with(['room', 'pengaju', 'status'])
            ->where('id_user_pengaju', $user->id_user)
            ->whereIn('id_status', [1, 4, 5]) // Filter: Diterima (1), Berlangsung (4), Selesai (5)
            ->whereBetween('tanggal', [\Carbon\Carbon::now()->toDateString(), \Carbon\Carbon::now()->addDays(7)->toDateString()])
            ->orderBy('tanggal', 'asc')
            ->orderBy('waktu_start', 'asc')
            ->get();

        return view('pic.dashboard', compact('rapatBaruDibuat', 'rapatTigaHariTerakhir', 'totalMenunggu', 'totalAkanDatang', 'totalPengajuan'));
    }

    public function dashboardTables()
    {
        $user = Auth::user();

        $rapatBaruDibuat = Rapat::with(['room', 'pengaju', 'status'])
            ->where('id_user_pengaju', $user->id_user)
            ->where('created_at', '>=', \Carbon\Carbon::now()->subDays(3))
            ->latest()
            ->get();

        $rapatTigaHariTerakhir = Rapat::with(['room', 'pengaju', 'status'])
            ->where('id_user_pengaju', $user->id_user)
            ->whereIn('id_status', [1, 4, 5]) // Filter: Diterima (1), Berlangsung (4), Selesai (5)
            ->whereBetween('tanggal', [\Carbon\Carbon::now()->toDateString(), \Carbon\Carbon::now()->addDays(7)->toDateString()])
            ->orderBy('tanggal', 'asc')
            ->orderBy('waktu_start', 'asc')
            ->get();

        return view('pic.dashboard-partials', compact('rapatBaruDibuat', 'rapatTigaHariTerakhir'));
    }

    public function index(Request $request)
    {
        $user = Auth::user();
        $query = Rapat::where('id_user_pengaju', $user->id_user)
            ->with(['room', 'status', 'cabang']);

        // Search by Judul
        if ($request->has('search') && $request->search != '') {
            $query->where('judul', 'like', '%' . $request->search . '%');
        }

        // Sorting
        $sort = $request->get('sort', 'created_at'); // Default sort
        $direction = $request->get('direction', 'desc');

        if ($sort == 'status') {
            // Custom sort for status: Selesai (5), Berlangsung (4), Menunggu (3), Ditolak (2), Diterima (1)
            // Adjust order as per user request "selesai, berlangsung, menunggu, ditolak"
            // Assuming IDs: 5=Selesai, 4=Berlangsung, 3=Menunggu, 2=Ditolak, 1=Diterima
            $query->orderByRaw("FIELD(id_status, 5, 4, 3, 2, 1) " . $direction);
        } elseif (in_array($sort, ['judul', 'tanggal', 'waktu_start'])) {
            $query->orderBy($sort, $direction);
        } else {
            $query->orderBy('created_at', 'desc');
        }

        $meetings = $query->paginate(10)->withQueryString();
        $cabangs = Cabang::all();
        $allRapats = Rapat::all(); // For room availability check

        return view('pic.meetings.index', compact('meetings', 'cabangs', 'allRapats'));
    }

    public function create()
    {
        $cabangs = Cabang::all();
        $rooms = Room::all();
        $allRapats = Rapat::all(); // Needed for availability check
        
        return view('pic.meetings.create', compact('cabangs', 'rooms', 'allRapats'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'judul' => 'required|string|max:255',
            'id_cabang' => 'required|exists:cabang,id',
            'id_room' => 'required|exists:room,id_room',
            'tanggal' => 'required|date',
            'waktu_start' => 'required',
            'waktu_end' => 'required|after:waktu_start',
            'desc' => 'nullable|string',
            'files_materi.*' => 'nullable|file|mimes:jpg,jpeg,png,pdf,doc,docx,ppt,pptx,xls,xlsx,txt,zip,rar,7z,mp4,mp3,wav|max:20480',
            'files_notulensi.*' => 'nullable|file|mimes:jpg,jpeg,png,pdf,doc,docx,ppt,pptx,xls,xlsx,txt,zip,rar,7z,mp4,mp3,wav|max:20480',
            'files_dokumentasi.*' => 'nullable|file|mimes:jpg,jpeg,png,pdf,doc,docx,ppt,pptx,xls,xlsx,txt,zip,rar,7z,mp4,mp3,wav|max:20480',
            'files_lainnya.*' => 'nullable|file|mimes:jpg,jpeg,png,pdf,doc,docx,ppt,pptx,xls,xlsx,txt,zip,rar,7z,mp4,mp3,wav|max:20480',
        ]);

        $rapat = new Rapat();
        $rapat->judul = $request->judul;
        $rapat->id_cabang = $request->id_cabang;
        $rapat->id_room = $request->id_room;
        $rapat->tanggal = $request->tanggal;
        $rapat->waktu_start = $request->waktu_start;
        $rapat->waktu_end = $request->waktu_end;
        $rapat->desc = $request->desc;
        $rapat->id_user_pengaju = Auth::id();
        $rapat->id_status = 3; // Default status: Menunggu (Baru Diajukan)

        $rapat->save();

        // Kirim Notifikasi ke Admin
        $admins = User::where('id_role', 1)->get();
        if ($admins->count() > 0) {
            Notification::send($admins, new NewMeetingNotification($rapat, Auth::user()->nama));
        }

        // Trigger update dashboard secara realtime
        \App\Events\DashboardUpdate::dispatch($rapat->id_rapat, $rapat->id_status);

        // Handle File Uploads
        // Helper function untuk upload file (Sama seperti RapatController)
        $uploadFiles = function ($files, $categoryId) use ($rapat) {
            if ($files) {
                foreach ($files as $file) {
                    $path = $file->store('public/rapat_files/'.$rapat->id_rapat);
                    $rapat->files()->create([
                        'file_name' => $file->getClientOriginalName(),
                        'file_path' => $path,
                        'file_type' => $file->getMimeType(),
                        'file_size' => $file->getSize(),
                        'id_categories' => $categoryId,
                    ]);
                }
            }
        };

        // Proses upload untuk setiap kategori
        $uploadFiles($request->file('files_materi'), 1);
        $uploadFiles($request->file('files_notulensi'), 2);
        $uploadFiles($request->file('files_dokumentasi'), 3);
        $uploadFiles($request->file('files_lainnya'), 4);

        return redirect()->route('pic.meetings.index')->with('success', 'Rapat berhasil diajukan.')->with('highlight_id', $rapat->id_rapat);
    }

    public function show(Rapat $rapat)
    {
        // Ensure the user owns this meeting
        if ($rapat->id_user_pengaju != Auth::id()) {
            if (request()->ajax()) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }
            abort(403);
        }

        // Eagerly load all required relationships
        $rapat->load(['room', 'status', 'cabang', 'pengaju', 'files']);

        if (request()->ajax()) {
            try {
                // Determine status class based on status ID
                $statusClass = 'bg-secondary'; // Default
                switch ($rapat->id_status) {
                    case 1: $statusClass = 'bg-success'; break;   // Diterima
                    case 2: $statusClass = 'bg-danger'; break;    // Ditolak
                    case 3: $statusClass = 'bg-warning text-dark'; break; // Menunggu
                    case 4: $statusClass = 'bg-primary'; break;   // Berlangsung
                    case 5: $statusClass = 'bg-dark'; break;      // Selesai
                }

                $response = [
                    'judul' => $rapat->judul ?? '-',
                    'status' => $rapat->status ? $rapat->status->status_rapat : '-',
                    'status_class' => $statusClass,
                    'rejection_note' => $rapat->rejection_note,
                    'cabang' => $rapat->cabang ? $rapat->cabang->cabang : '-',
                    'room' => $rapat->room ? $rapat->room->room : '-',
                    'tanggal' => $rapat->tanggal ?? '-',
                    'tanggal_formatted' => $rapat->tanggal ? \Carbon\Carbon::parse($rapat->tanggal)->translatedFormat('d F Y') : '-',
                    'waktu' => ($rapat->waktu_start ? substr($rapat->waktu_start, 0, 5) : '') . ' - ' . ($rapat->waktu_end ? substr($rapat->waktu_end, 0, 5) : ''),
                    'deskripsi' => $rapat->desc ?? '-',
                    'pengaju' => $rapat->pengaju ? ($rapat->pengaju->nama ?? $rapat->pengaju->name ?? '-') : '-',
                    'files' => $rapat->files->map(function ($file) {
                        return [
                            'id_file' => $file->id_file,
                            'file_name' => $file->file_name,
                            'file_type' => $file->file_type,
                            'id_categories' => $file->id_categories ?? 4, // Default to 'Lainnya' if not set
                            'download_url' => route('meetings.downloadFile', $file->id_file),
                            'delete_url' => route('pic.meetings.destroyFile', $file->id_file),
                        ];
                    }),
                    'urls' => [
                        'absensi' => route('pic.meetings.absensi', $rapat->id_rapat),
                        'qr' => route('pic.meetings.qr', $rapat->id_rapat),
                        'upload_file' => route('pic.meetings.storeFile', $rapat->id_rapat),
                    ]
                ];
                
  
                
                return response()->json($response);
            } catch (\Exception $e) {

                return response()->json(['error' => 'Terjadi kesalahan: ' . $e->getMessage()], 500);
            }
        }

        return redirect()->route('pic.meetings.index');
    }

    public function destroy($id)
    {
        $rapat = Rapat::findOrFail($id);

        // Ensure the user owns this meeting
        if ($rapat->id_user_pengaju != Auth::id()) {
            abort(403);
        }

        // Only allow deletion if status is "Baru Diajukan" (ID 3)
        if ($rapat->id_status != 3) {
            return back()->with('error', 'Hanya rapat yang baru diajukan yang dapat dihapus.');
        }

        $rapat->delete();

        return redirect()->route('pic.meetings.index')->with('success', 'Rapat berhasil dihapus.');
    }
    
    /**
     * Mark meeting as finished
     */
    public function finishMeeting(Rapat $rapat)
    {
        // Ensure the user owns this meeting
        if ($rapat->id_user_pengaju != Auth::id()) {
            abort(403);
        }

        // Only allow finishing if status is "Berlangsung" (ID 4)
        if ($rapat->id_status != 4) {
            return back()->with('error', 'Hanya rapat yang sedang berlangsung yang dapat diselesaikan.');
        }

        // Update status to "Selesai" (ID 5)
        $rapat->id_status = 5;
        $rapat->save();

        // Trigger update dashboard secara realtime
        \App\Events\DashboardUpdate::dispatch($rapat->id_rapat, $rapat->id_status);

        // Note: Room availability is automatically determined by checking meeting status and time
        // No need to manually update room status as it's based on active meetings

        return redirect()->route('pic.meetings.index')->with('success', 'Rapat berhasil diselesaikan. Ruangan kini tersedia kembali.');
    }
    
    // Reuse logic for Absensi and QR Code
    // Ideally these should be in a service or trait, but for now we can duplicate or call if appropriate.
    // Since RapatController methods might be protected by Admin middleware, we should implement them here or ensure routes use this controller.

    public function showAbsensi(Rapat $rapat)
    {
        if ($rapat->id_user_pengaju != Auth::id()) {
            abort(403);
        }
        
        // Load absensi with polymorphic attendable relationship
        $absensi = $rapat->absensi()->with('attendable')->get();
        
        // Load division for User attendables only
        $absensi->where('attendable_type', \App\Models\User::class)->load('attendable.division');
        
        return view('pic.meetings.absensi', compact('rapat', 'absensi'));
    }

    /**
     * Export attendance data to Excel for PIC users
     */
    public function exportAbsensi($id)
    {
        // Find the meeting
        $rapat = Rapat::findOrFail($id);
        
        // Ensure the user owns this meeting
        if ($rapat->id_user_pengaju != Auth::id()) {
            abort(403);
        }
        
        // Fetch attendance data with relationships
        $absensi = \App\Models\Absensi::where('id_rapat', $id)
            ->with('attendable')
            ->orderBy('waktu_absen', 'asc')
            ->get();
            
        // Load division for User attendables
        $absensi->where('attendable_type', \App\Models\User::class)->load('attendable.division');
        
        // Generate filename
        $fileName = 'laporan-absensi-'.\Illuminate\Support\Str::slug($rapat->judul).'-'.date('Y-m-d').'.xlsx';
        
        // Use the existing export class
        return \Maatwebsite\Excel\Facades\Excel::download(new \App\Exports\AbsensiRapatExport($absensi), $fileName);
    }



    public function showQrCode(Rapat $rapat)
    {
        if ($rapat->id_user_pengaju != Auth::id()) {
            abort(403);
        }
        
        // Only allow QR code access for ongoing meetings (status = 4)
        if ($rapat->id_status != 4) {
            return redirect()->route('pic.meetings.index')
                ->with('error', 'QR Code Absensi hanya tersedia untuk rapat yang sedang berlangsung.');
        }
        
        return view('pic.meetings.qr', compact('rapat'));
    }

    public function showGuestQr(Rapat $rapat)
    {
        if ($rapat->id_user_pengaju != Auth::id()) {
            abort(403);
        }
        
        // Only allow guest QR access for ongoing meetings (status = 4)
        if ($rapat->id_status != 4) {
            return redirect()->route('pic.meetings.index')
                ->with('error', 'QR Mode Tamu hanya tersedia untuk rapat yang sedang berlangsung.');
        }
        
        // Membuat URL untuk halaman login tamu
        $guestUrl = route('meetings.guestLogin', $rapat->id_rapat);

        // Mengembalikan view dengan data yang diperlukan
        return view('pic.meetings.guest-qr', compact('rapat', 'guestUrl'));
    }

    /**
     * Mengembalikan SVG QR Code untuk rapat tertentu.
     * Digunakan untuk pembaruan AJAX di halaman display QR.
     */
    public function getQrCodeSvg(Rapat $rapat)
    {
        if ($rapat->id_user_pengaju != Auth::id()) {
            abort(403);
        }
        
        // Only generate QR for ongoing meetings (status = 4)
        if ($rapat->id_status != 4) {
            abort(403, 'QR Code only available for ongoing meetings');
        }
        
        // Pastikan rapat memiliki token
        $token = $rapat->current_qr_token ?? 'invalid-token';

        $svg = QrCode::size(400)->generate($token);

        return response($svg)->header('Content-Type', 'image/svg+xml');
    }

    public function showRecentActivityReport()
    {
        $title = 'Laporan Aktivitas Rapat (7 Hari Kedepan)';

        // Mengambil semua data rapat dari hari ini s.d 7 hari kedepan
        $rapatTigaHariTerakhir = Rapat::with(['pengaju', 'status', 'room'])
            ->where('id_user_pengaju', Auth::id()) // Filter by user
            ->whereBetween('tanggal', [\Carbon\Carbon::now()->toDateString(), \Carbon\Carbon::now()->addDays(7)->toDateString()])
            ->whereIn('id_status', [1, 4, 5]) // Filter: Diterima (1), Berlangsung (4), Selesai (5)
            ->orderBy('tanggal', 'asc')
            ->orderBy('waktu_start', 'asc')
            ->get();

        // Mengirim data ke view khusus laporan
        return view('reports.recent-activity', compact('rapatTigaHariTerakhir', 'title') + ['backRoute' => 'pic.dashboard']);
    }

    public function showNewlyCreatedReport()
    {
        $rapatBaruDibuat = Rapat::with(['room', 'pengaju', 'status'])
            ->where('id_user_pengaju', Auth::id()) // Filter by user
            ->where('created_at', '>=', \Carbon\Carbon::now()->subDays(3))
            ->orderBy('created_at', 'desc')
            ->get();

        return view('reports.newly-created', [
            'title' => 'Laporan Rapat Baru Dibuat',
            'rapatBaruDibuat' => $rapatBaruDibuat,
            'backRoute' => 'pic.dashboard'
        ]);
    }

    public function storeFile(Request $request, Rapat $rapat)
    {
        // Ensure the user owns this meeting
        if ($rapat->id_user_pengaju != Auth::id()) {
            abort(403);
        }

        $request->validate([
            'file' => 'required|file|mimes:jpg,jpeg,png,pdf,doc,docx,ppt,pptx,xls,xlsx,txt,zip,rar,7z,mp4,mp3,wav|max:20480', // Max 20MB
            'id_categories' => 'required|integer|in:1,2,3,4', // Validate category
        ]);

        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $path = $file->store('public/rapat_files/'.$rapat->id_rapat);
            
            $rapatFile = $rapat->files()->create([
                'file_name' => $file->getClientOriginalName(),
                'file_path' => $path,
                'file_type' => $file->getMimeType(),
                'file_size' => $file->getSize(),
                'id_categories' => $request->id_categories, // Save category
            ]);

            return response()->json([
                'success' => true,
                'message' => 'File berhasil diunggah.',
                'file' => [
                    'id_file' => $rapatFile->id_file,
                    'file_name' => $rapatFile->file_name,
                    'file_path' => str_replace('public/', '', $rapatFile->file_path),
                    'file_type' => $rapatFile->file_type,
                    'id_categories' => $rapatFile->id_categories,
                    'download_url' => route('meetings.downloadFile', $rapatFile->id_file),
                    'delete_url' => route('pic.meetings.destroyFile', $rapatFile->id_file),
                ]
            ]);
        }

        return response()->json(['success' => false, 'message' => 'Gagal mengunggah file.'], 400);
    }

    public function destroyFile(\App\Models\RapatFile $file)
    {
        $rapat = $file->rapat;

        // Ensure the user owns the meeting associated with this file
        if ($rapat->id_user_pengaju != Auth::id()) {
            abort(403);
        }

        try {
            // Hapus file dari storage
            \Illuminate\Support\Facades\Storage::delete($file->file_path);
            // Hapus record dari database
            $file->delete();

            return response()->json(['success' => true, 'message' => 'File berhasil dihapus.']);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghapus file.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
