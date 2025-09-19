<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateAbsensiTable extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('absensi', function (Blueprint $table) {
            $table->id('id_absensi');
            $table->unsignedBigInteger('id_rapat'); // Perbaikan tipe data
            $table->unsignedBigInteger('id_user');
            $table->string('foto', 255);
            $table->decimal('latitude', 10, 8);
            $table->decimal('longitude', 11, 8);
            $table->timestamp('waktu_absen')->useCurrent();
            $table->enum('status', ['hadir', 'izin', 'sakit', 'alpha'])->default('hadir');

            // Foreign Keys
            $table->foreign('id_rapat')->references('id_rapat')->on('rapat')->onDelete('cascade'); // Perbaikan nama tabel
            $table->foreign('id_user')->references('id_user')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('absensi');
    }
}