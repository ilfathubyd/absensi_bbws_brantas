<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class RoomSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('room')->insert([
            ['id_room' => 1, 'room' => 'RUANG PERTEMUAN BENDUNGAN SUTAMI', 'id_cabang' => 110],
            ['id_room' => 2, 'room' => 'RUANG PERTEMUAN BENDUNGAN SUTAMI', 'id_cabang' => 110],
            ['id_room' => 3, 'room' => 'RUANG PERTEMUAN BENDUNGAN TUGU', 'id_cabang' => 110],
            ['id_room' => 4, 'room' => 'RUANG RAPAT PPK PROGRAM', 'id_cabang' => 110],
            ['id_room' => 5, 'room' => 'RUANG PERTEMUAN GUNUNG SEMERU (PJSA BAWAH)', 'id_cabang' => 110],
            ['id_room' => 6, 'room' => 'RUANG RAPAT SEMANTOK (PJSA ATAS / BENDUNGAN)', 'id_cabang' => 110],
            ['id_room' => 7, 'room' => 'RUANG RAPAT BENDUNGAN NIPAH', 'id_cabang' => 110],
            ['id_room' => 8, 'room' => 'RUANG RAPAT SATKER PJPA (PJSA ATAS)', 'id_cabang' => 110],
            ['id_room' => 9, 'room' => 'RUANG RAPAT BIDANG KPI SDA', 'id_cabang' => 110],
            ['id_room' => 10, 'room' => 'RUANG PERTEMUAN BENDUNGAN BAGONG (BID. OP)', 'id_cabang' => 110],
            ['id_room' => 11, 'room' => 'RUANG RAPAT KPISDA', 'id_cabang' => 110],
        ]);
    }
}
