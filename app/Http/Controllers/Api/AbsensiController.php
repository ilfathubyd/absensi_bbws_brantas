<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Absensi;
use App\Models\Rapat;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AbsensiController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'id_rapat' => 'required|exists:rapat,id_rapat',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);

        $user = Auth::user();

        // PERBAIKAN: Cek apakah user adalah peserta rapat atau pengaju rapat
        $rapat = Rapat::with('peserta')->find($request->id_rapat);

        $isPengaju = $rapat->id_user_pengaju == $user->id_user;
        $isPeserta = $rapat->peserta->contains($user->id_user);

        if (! $isPengaju && ! $isPeserta) {
            return response()->json([
                'message' => 'Anda tidak terdaftar sebagai peserta rapat ini.',
            ], 403); // 403 Forbidden
        }

        // Cek apakah user sudah absen untuk rapat ini
        $existingAbsensi = Absensi::where('id_user', $user->id_user)
            ->where('id_rapat', $request->id_rapat)
            ->first();

        if ($existingAbsensi) {
            return response()->json([
                'message' => 'Anda sudah melakukan absensi untuk rapat ini.',
            ], 409); // 409 Conflict
        }

        // Buat record absensi baru
        $absensi = Absensi::create([
            'id_user' => $user->id_user,
            'id_rapat' => $request->id_rapat,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'waktu_absen' => now(),
            'status' => 'hadir', // Default status saat absen
            'foto' => 'jika ada upload foto, proses di sini',
        ]);

        return response()->json([
            'message' => 'Absensi berhasil dicatat.',
            'data' => $absensi,
        ], 201); // 201 Created
    }

    /**
     * Endpoint untuk melihat riwayat absensi user yang sedang login.
     */
    public function history()
    {
        $user = Auth::user();

        $history = Absensi::where('id_user', $user->id_user)
            ->with('rapat:id_rapat,judul,tanggal') // Mengambil data rapat terkait
            ->orderBy('waktu_absen', 'desc')
            ->get();

        return response()->json(['data' => $history]);
    }
}
