<?php

namespace App\Http\Controllers\Website;

use App\Http\Controllers\Controller;
use App\Models\Guest;
use Illuminate\Http\Request;

class GuestController extends Controller
{
    public function index(Request $request)
    {               
        $query = Guest::with(['absensi' => function ($query) {
            $query->latest('waktu_absen');
        }]);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('nama', 'like', "%{$search}%")
                  ->orWhere('asal_instansi', 'like', "%{$search}%")
                  ->orWhere('jabatan', 'like', "%{$search}%");
            });
        }

        // Sorting
        $sort = $request->get('sort', 'nama');
        $direction = $request->get('direction', 'asc');
        
        // Handle sorting by related columns if needed, but for now basic sorting
        if (in_array($sort, ['nama', 'asal_instansi', 'jabatan', 'created_at'])) {
            $query->orderBy($sort, $direction);
        } else {
            $query->orderBy('created_at', 'desc');
        }

        $guests = $query->paginate(10);

        return view('guest.index', compact('guests', 'sort', 'direction'));
    }

    public function destroy($id)
    {
        try {
            $guest = Guest::findOrFail($id);

            foreach ($guest->absensi as $absen) {
                $absen->device_token = null;
                $absen->save();
            }

            // Jangan hapus data guest atau absensi secara fisik
            // $guest->delete(); 

            return redirect()->route('guests.index')->with('success', 'Device ID tamu berhasil direset. Data absensi tetap tersimpan.');
        } catch (\Exception $e) {
            return redirect()->route('guests.index')->with('error', 'Gagal mereset data tamu: ' . $e->getMessage());
        }
    }
}
