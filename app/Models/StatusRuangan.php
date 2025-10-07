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
        Schema::create('status_ruangan', function (Blueprint $table) {
            // Kolom ID unik untuk setiap status (Primary Key)
            $table->id('id_ruangan');

            // Kolom untuk menampung nama status, harus unik
            $table->string('nama_status')->unique();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('status_ruangans');
    }

    public function Room(): HasMany
    {
        return $this->hasMany(Room::class, 'status_ruangan');
    }
};
