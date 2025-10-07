<?php

namespace Database\Seeders;

use App\Models\StatusRuangan;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;


class StatusRuanganSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
          DB::table('status_ruangan')->insert([
            ['id' => 1, 'nama_status' => 'Tersedia'],
            ['id' => 2, 'nama_status' => 'Tidak Tersedia'],
            ['id' => 3, 'nama_status' => 'Dalam Perbaikan'],
        ]);
    }
}
