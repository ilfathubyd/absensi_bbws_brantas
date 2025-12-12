<?php

namespace App\Http\Controllers\Api;

use App\Exports\AbsensiExport;
use App\Http\Controllers\Controller;
use App\Models\Absensi;
use App\Models\Rapat;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Maatwebsite\Excel\Facades\Excel;

class AbsensiController extends Controller
{
    public function store(Request $request)
    {
        // Menonaktifkan endpoint ini untuk memaksa absensi via QR Code.
        // Endpoint yang benar adalah POST /api/rapat/scan-absen
        return response()->json([
            'message' => 'Metode absensi ini tidak digunakan. Silakan gunakan pemindai QR Code.',
        ], 405); // 405 Method Not Allowed
    }

    /**
     * Endpoint untuk melihat riwayat absensi user yang sedang login.
     */
    public function history()
    {
        try {
            $user = Auth::user();
            
            if (!$user) {
                return response()->json(['error' => 'User not authenticated'], 401);
            }

            $history = Absensi::where('attendable_id', $user->id_user)
                ->where('attendable_type', \App\Models\User::class)
                ->with(['rapat' => function($query) {
                    $query->with('room:id_room,room');
                }])
                ->orderBy('waktu_absen', 'desc')
                ->get();


            return response()->json(['data' => $history], 200);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to fetch history',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function export()
    {
        return Excel::download(new AbsensiExport, 'absensi.xlsx');
    }
}
