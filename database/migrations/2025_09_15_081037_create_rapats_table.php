<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateRapatsTable extends Migration
{
    public function up()
    {
        Schema::create('rapat', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('id_room');
            $table->unsignedInteger('id_cabang');
            $table->string('judul', 100);
            $table->date('tanggal');
            $table->time('waktu_start');
            $table->time('waktu_end');
            $table->unsignedInteger('id_status');
            $table->unsignedBigInteger('id_user_pengaju');
            $table->string('desc', 100)->nullable();
            $table->timestamps('created_at');
            $table->timestamps('updated_at');

            // Foreign Keys
            $table->foreign('id_room')->references('id')->on('rooms')->onDelete('cascade');
            $table->foreign('id_cabang')->references('id')->on('cabangs')->onDelete('cascade');
            $table->foreign('id_status')->references('id')->on('status_rapats')->onDelete('cascade');
            $table->foreign('id_user_pengaju')->references('id')->on('users')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('rapats');
    }
}
