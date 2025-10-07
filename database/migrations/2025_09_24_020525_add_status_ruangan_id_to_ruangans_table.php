<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('room', function (Blueprint $table) {
                // 1. Tambahkan kolom foreign key
            // 'status_ruangan_id' akan merujuk ke 'id' di tabel 'status_ruangans'
            $table->foreignId('status_ruangan_id')
                  ->after('id_room') // Opsional: menempatkan kolom setelah kolom 'id'
                  ->constrained('status_ruangan')
                  ->onDelete('restrict'); // Mencegah status dihapus jika masih dipakai ruangan
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('room', function (Blueprint $table) {
            //
        });
    }
};
