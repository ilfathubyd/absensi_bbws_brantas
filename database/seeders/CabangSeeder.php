<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class CabangSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('cabang')->insert([
            ['id' => 110, 'cabang' => 'Balai Besar Wilayah Sungai Brantas', 'alamat' => 'Balai Besar Wilayah Sungai Brantas', 'alamat' => 'Jl. Raya Menganti No.312, Wiyung, Kec. Wiyung, Surabaya, Jawa Timur 60227'],
        ]);
    }
}
