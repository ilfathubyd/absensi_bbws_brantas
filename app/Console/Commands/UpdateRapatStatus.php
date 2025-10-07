<?php

namespace App\Console\Commands;

use App\Models\Rapat;
use Carbon\Carbon;
use Illuminate\Console\Command;

class UpdateRapatStatus extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'rapat:update-status';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Update status rapat menjadi Berlangsung atau Selesai berdasarkan waktu';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $now = Carbon::now();
        $this->info('Memulai pengecekan status rapat pada: '.$now->toDateTimeString());

        // 1. Ubah status menjadi "Berlangsung" (id_status = 4)
        // Kondisi:
        // - Status saat ini adalah "Diterima" (id_status = 1)
        // - Waktu sekarang >= waktu mulai DAN Waktu sekarang < waktu selesai
        $rapatBerlangsung = Rapat::where('id_status', 1) // Diterima
            ->whereRaw('? >= CONCAT(tanggal, " ", waktu_start)', [$now])
            ->whereRaw('? < CONCAT(tanggal, " ", waktu_end)', [$now])
            ->update(['id_status' => 4]); // Ubah ke Berlangsung

        if ($rapatBerlangsung > 0) {
            $this->info("{$rapatBerlangsung} rapat diubah statusnya menjadi 'Berlangsung'.");
        }

        // 2. Ubah status menjadi "Selesai" (id_status = 5) dari rapat yang "Berlangsung" atau "Diterima"
        // Kondisi:
        // - Status saat ini adalah "Berlangsung" (4) ATAU "Diterima" (1)
        // - Waktu sekarang sudah melewati waktu selesai rapat
        //   (Ini juga menangani kasus jika scheduler sempat down dan melewatkan update ke "Berlangsung")
        $rapatSelesai = Rapat::whereIn('id_status', [1, 4]) // Diterima atau Berlangsung
            ->whereRaw('? >= CONCAT(tanggal, " ", waktu_end)', [$now])
            ->update(['id_status' => 5]); // Ubah ke Selesai

        if ($rapatSelesai > 0) {
            $this->info("{$rapatSelesai} rapat diubah statusnya menjadi 'Selesai'.");
        }

        $this->info('Pengecekan status rapat selesai.');

        return 0;
    }
}
