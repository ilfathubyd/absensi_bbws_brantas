<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateRapatsTable extends Migration
{
    public function up(): void
    {
        Schema::create('rapat', function (Blueprint $table) {
            $table->id('id_rapat');
            $table->unsignedBigInteger('id_room');
            $table->unsignedBigInteger('id_cabang');
            $table->string('judul', 100);
            $table->dateTime('waktu_start');
            $table->dateTime('waktu_end');
            $table->unsignedBigInteger('id_status'); // Perbaikan tipe data
            $table->unsignedBigInteger('id_user_pengaju');
            $table->string('desc', 100)->nullable();
            $table->timestamps();

            // Foreign Keys
            $table->foreign('id_room')->references('id')->on('room')->onDelete('cascade');
            $table->foreign('id_cabang')->references('id')->on('cabang')->onDelete('cascade');
            $table->foreign('id_status')->references('id')->on('status_rapat')->onDelete('cascade'); // Perbaikan referensi kolom
            $table->foreign('id_user_pengaju')->references('id_user')->on('users')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('rapat');
    }
}