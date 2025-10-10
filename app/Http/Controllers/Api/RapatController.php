<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rapat;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RapatController extends Controller
{
    // GET: /api/rapat
    public function index()
    {
        $rapat = Rapat::with(['room', 'status', 'pengaju', 'peserta'])->get();

        return response()->json($rapat);
    }

    // POST: /api/rapat
    public function store(Request $request)
    {
        // 1. Validasi input yang dikirim oleh user
        $validatedData = $request->validate([
            'id_cabang' => 'required|exists:cabang,id', // Menambahkan validasi id_cabang
            'id_room' => 'required|exists:room,id_room',
            'judul' => 'required|string|max:100',
            'tanggal' => 'required|date',
            'waktu_start' => 'required', // Format jam:menit
            'waktu_end' => 'after:waktu_start',
            'desc' => 'nullable|string|max:100',
            'peserta_ids' => 'nullable|array', // Terima array ID peserta
            'peserta_ids.*' => 'exists:users,id_user', // Pastikan setiap ID ada di tabel users
        ]);

        // 2. Ambil data user yang sedang login
        $user = Auth::user();

        // 3. Tambahkan id_user_pengaju dari user yang login (lebih aman)
        $validatedData['id_user_pengaju'] = $user->id_user;

        // 4. Terapkan logika untuk id_status berdasarkan role user
        // Asumsi: Role Admin memiliki id_role = 1
        // Asumsi: Role PIC memiliki id_role = 2
        if ($user->id_role == 1) { // Jika yang membuat adalah Admin
            $validatedData['id_status'] = 1; // Langsung disetujui
        } elseif ($user->id_role == 2) { // Jika yang membuat adalah PIC
            $validatedData['id_status'] = 3; // Menunggu Persetujuan Admin
        } else {
            // Jika role tidak diizinkan, kembalikan response error yang jelas.
            return response()->json([
                'message' => 'Anda tidak memiliki izin untuk membuat rapat.',
            ], 403); // 403 Forbidden -> User tidak punya izin.
        }

        // 5. Buat data rapat dengan data yang sudah dimodifikasi
        $rapat = Rapat::create($validatedData);

        // 6. Jika ada peserta_ids, lampirkan (attach) ke rapat yang baru dibuat
        if (! empty($validatedData['peserta_ids'])) {
            $rapat->peserta()->attach($validatedData['peserta_ids']);
        }

        // 7. Kembalikan response
        return response()->json([
            'message' => 'Rapat berhasil dibuat.',
            'data' => $rapat->load(['room', 'status', 'pengaju', 'peserta']), // Muat semua relasi yang relevan
        ], 201);
    }

    // GET: /api/rapat/{id}
    public function show($id)
    {
        $rapat = Rapat::with(['room', 'status', 'pengaju', 'peserta'])->findOrFail($id);

        return response()->json($rapat);
    }

    // GET: /api/rapat/saya (Method Baru)
    public function rapatSaya()
    {
        // 1. Ambil ID user yang sedang login
        $userId = Auth::user()->id_user;

        // 2. Ambil data rapat yang memiliki 'id_user_pengaju' sama dengan ID user yang login
        $rapat = Rapat::with(['room', 'status', 'pengaju', 'peserta'])
            ->where('id_user_pengaju', $userId)
            ->get();

        // 3. Kembalikan response dalam bentuk JSON
        return response()->json($rapat);
    }

    // PUT: /api/rapat/{id}
    public function update(Request $request, $id)
    {
        $rapat = Rapat::findOrFail($id);

        // Validasi data yang masuk, mirip dengan store
        $validatedData = $request->validate([
            'id_room' => 'sometimes|required|exists:room,id_room',
            'judul' => 'sometimes|required|string|max:100',
            'tanggal' => 'sometimes|required|date',
            'waktu_start' => 'sometimes|required',
            'waktu_end' => 'sometimes|after:waktu_start',
            'desc' => 'nullable|string|max:100',
            'peserta_ids' => 'nullable|array',
            'peserta_ids.*' => 'exists:users,id_user',
        ]);

        $rapat->update($validatedData);

        // Gunakan sync() untuk memperbarui daftar peserta.
        // Ini akan otomatis menambah/menghapus peserta sesuai array yang diberikan.
        if ($request->has('peserta_ids')) {
            $rapat->peserta()->sync($validatedData['peserta_ids']);
        }

        return response()->json([
            'message' => 'Rapat berhasil diperbarui',
            'data' => $rapat->load(['room', 'status', 'pengaju', 'peserta']), // Muat ulang relasi setelah update
        ]);
    }

    // POST: /api/rapat/{id}/setujui
    public function setujuiRapat(Request $request, $id)
    {
        // $this->authorize('admin-auth'); // Hanya Admin yang bisa menyetujui

        // 2. Cari rapat berdasarkan ID
        $rapat = Rapat::findOrFail($id);

        // 3. Ubah statusnya menjadi 'Disetujui'
        // Asumsi: id_status = 1 adalah 'Disetujui'
        $rapat->id_status = 1;
        $rapat->save(); // Simpan perubahan

        // 4. Kembalikan response sukses
        return response()->json([
            'message' => 'Rapat berhasil disetujui.',
            'data' => $rapat,
        ]);
    }

    // (Opsional) Fungsi untuk menolak rapat
    // POST: /api/rapat/{id}/tolak
    public function tolakRapat(Request $request, $id)
    {
        $this->authorize('admin-auth'); // Hanya Admin yang bisa menyetujui

        $rapat = Rapat::findOrFail($id);

        // Asumsi: id_status = 2 adalah 'Ditolak'
        $rapat->id_status = 2;
        $rapat->save();

        return response()->json([
            'message' => 'Rapat telah ditolak.',
            'data' => $rapat,
        ]);
    }

    // DELETE: /api/rapat/{id}
    public function destroy($id)
    {
        $rapat = Rapat::findOrFail($id);
        $rapat->delete();

        return response()->json(['message' => 'Rapat berhasil dihapus']);
    }

    /**
     * Mengambil daftar peserta untuk rapat tertentu.
     * GET: /api/rapat/{id}/peserta
     */
    public function getPesertaRapat($id)
    {
        $rapat = Rapat::with('peserta')->findOrFail($id);

        return response()->json([
            'message' => 'Berhasil mengambil data peserta rapat.',
            'data' => $rapat->peserta,
        ]);
    }

    /**
     * Menambahkan peserta ke rapat yang sudah ada.
     * POST: /api/rapat/{id}/peserta
     */
    public function addPesertaRapat(Request $request, $id)
    {
        // 1. Validasi input yang dikirim
        $validatedData = $request->validate([
            'peserta_ids' => 'required|array',
            'peserta_ids.*' => 'exists:users,id_user', // Pastikan setiap ID ada di tabel users
        ]);

        // 2. Cari rapat berdasarkan ID
        $rapat = Rapat::findOrFail($id);

        // 3. Gunakan syncWithoutDetaching() untuk menambahkan peserta baru.
        // Metode ini lebih aman karena tidak akan menyebabkan error jika peserta
        // yang sama ditambahkan lagi (mencegah duplikasi) dan tidak menghapus peserta lama.
        $rapat->peserta()->syncWithoutDetaching($validatedData['peserta_ids']);

        // 4. Kembalikan response sukses dengan daftar peserta yang telah diperbarui
        return response()->json([
            'message' => 'Peserta berhasil ditambahkan ke rapat.',
            'data' => $rapat->load('peserta')->peserta, // Muat ulang relasi peserta dan kirim datanya
        ]);
    }
}
