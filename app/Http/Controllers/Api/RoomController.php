<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Room;
use Illuminate\Http\Request;
use App\Models\Cabang;

class RoomController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = Room::query();

        if ($request->has('cabang_id')) {
            $query->where('id', $request->cabang_id);
        }

        return response()->json($query->get());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }

    public function getRoomsByCabang(Cabang $cabang)
    {
        try {
            // Mengambil ruangan yang berelasi dengan $cabang
            // dan langsung memfilter berdasarkan status_ruang_id = 1 (misal: 'Tersedia')
            $rooms = $cabang->room()
                ->where('status_ruangan_id', 1)
                ->get();

            // Jika Anda ingin memuat relasi lain (misal: statusRuangan)
            // $rooms = $cabang->room()->with('statusRuangan')->where('status_ruang_id', 1)->get();

            return response()->json($rooms, 200);

        } catch (\Exception $e) {
            // Tangani jika terjadi error
            return response()->json([
                'message' => 'Gagal mengambil data ruangan.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
