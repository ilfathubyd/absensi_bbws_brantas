<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
public function up()
{
    Schema::create('rapat', function (Blueprint $table) {
        $table->id('id_rapat');
        $table->string('judul');
        $table->dateTime('waktu_start');
        $table->dateTime('waktu_end');
        $table->text('desc')->nullable();

        // Foreign keys
        $table->foreignId('id_room')->constrained('room', 'id_room')->onDelete('cascade');
        $table->foreignId('id_cabang')->constrained('cabang', 'id_cabang')->onDelete('cascade');
        $table->foreignId('id_status')->constrained('status_rapat', 'id_status')->onDelete('cascade');
        $table->foreignId('id_user_pengaju')->constrained('users', 'id')->onDelete('cascade');

        $table->timestamps();
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rapats');
    }
};
