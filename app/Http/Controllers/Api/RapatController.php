<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rapat;
use Illuminate\Http\Request;

class RapatController extends Controller
{
    // GET: /api/rapat
    public function index()
    {
        $rapat = Rapat::with(['room', 'status', 'pemegang', 'peserta'])->get();
        return response()->json($rapat);
    }

    // POST: /api/rapat
    public function store(Request $request)
    {
        $request->validate([
            'id_room' => 'required|exists:room,id_room',
            'judul' => 'required|string',
            'tanggal' => 'required|date',
            'waktu_start' => 'required',
            'waktu_end' => 'required',
            //'id_status' => 'required|exists:status_rapat,id_status',
            'id_user_pengaju' => 'required|exists:users,id',
        ]);

        $rapat = Rapat::create($request->all());

        return response()->json([
            'message' => 'Rapat berhasil dibuat',
            'data' => $rapat
        ], 201);
    }

    // GET: /api/rapat/{id}
    public function show($id)
    {
        $rapat = Rapat::with(['room', 'status', 'pemegang', 'peserta'])->findOrFail($id);
        return response()->json($rapat);
    }

    // PUT: /api/rapat/{id}
    public function update(Request $request, $id)
    {
        $rapat = Rapat::findOrFail($id);

        $rapat->update($request->all());

        return response()->json([
            'message' => 'Rapat berhasil diperbarui',
            'data' => $rapat
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
