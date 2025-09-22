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
            'waktu_end' => 'required|after:waktu_start',
            'desc' => 'nullable|string|max:100',
        ]);

        // 2. Ambil data user yang sedang login
        $user = Auth::user();

        // 3. Tambahkan id_user_pengaju dari user yang login (lebih aman)
        $validatedData['id_user_pengaju'] = $user->id_user;

        // 4. Terapkan logika untuk id_status berdasarkan role user
        // Asumsi: Role Admin memiliki id_role = 1
        // Asumsi: Role PIC memiliki id_role = 3
        if ($user->id_role == 1) { // Jika yang membuat adalah Admin
            $validatedData['id_status'] = 1; // Langsung disetujui
        } elseif ($user->id_role == 2) { // Jika yang membuat adalah PIC
            $validatedData['id_status'] = 3; // Menunggu Persetujuan Admin
        } else {
            // Jika role tidak diizinkan, langsung kembalikan response error.
            return response()->json([
                'message' => 'Rapat telah ditolak',
            ], 403); // 403 Forbidden -> User tidak punya izin.
        }

        // 5. Buat data rapat dengan data yang sudah dimodifikasi
        $rapat = Rapat::create($validatedData);

        // 6. Kembalikan response
        return response()->json([
            'message' => 'Rapat berhasil dibuat',
            'data' => $rapat->load(['room', 'status', 'pengaju']), // Muat relasi agar response lengkap
        ], 201);
    }

    // GET: /api/rapat/{id}
    public function show($id)
    {
        $rapat = Rapat::with(['room', 'status', 'pengaju', 'peserta'])->findOrFail($id);

        return response()->json($rapat);
    }

    // PUT: /api/rapat/{id}
    public function update(Request $request, $id)
    {
        $rapat = Rapat::findOrFail($id);

        $rapat->update($request->all());

        return response()->json([
            'message' => 'Rapat berhasil diperbarui',
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
}
