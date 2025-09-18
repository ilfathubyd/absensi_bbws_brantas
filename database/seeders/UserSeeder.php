<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        DB::table('users')->insert([
            [
                'id_role' => 1,
                'id_division' => 2000,
                'username' => 'admin',
                'name' => 'ALDI SANG ADMIN',
                'email' => 'admin@example.com',
                'phone' => '081234567890',
                'gender' => 'male',
                'password' => Hash::make('1'), // Ganti dengan password yang aman
                'photo' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id_role' => 2,
                'id_division' => 2001,
                'username' => 'pic',
                'name' => 'ALDI SANG PIC',
                'email' => 'pic@example.com',
                'phone' => '081234567890',
                'gender' => 'male',
                'password' => Hash::make('1'),
                'photo' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id_role' => 3,
                'id_division' => 2002,
                'username' => 'user',
                'name' => 'ALDI SANG USERS',
                'email' => 'user@example.com',
                'phone' => '081234567890',
                'gender' => 'female',
                'password' => Hash::make('1'),
                'photo' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}