<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePesertaRapatsTable extends Migration
{
    public function up()
    {
        Schema::create('peserta_rapats', function (Blueprint $table) {
            $table->unsignedInteger('id_rapat');
            $table->unsignedBigInteger('id_user');
            $table->timestamps();

            $table->primary(['id_rapat', 'id_user']);

            // Foreign Keys
            $table->foreign('id_rapat')->references('id')->on('rapats')->onDelete('cascade');
            $table->foreign('id_user')->references('id')->on('users')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('peserta_rapats');
    }
}