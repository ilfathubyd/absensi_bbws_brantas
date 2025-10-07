<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Rapat extends Model
{
    use HasFactory;

    protected $table = 'rapat';

    protected $primaryKey = 'id_rapat';

    protected $fillable = [
        'id_room',
        'id_cabang',
        'id_status',
        'judul',
        'tanggal',
        'waktu_start',
        'waktu_end',
        'id_user_pengaju',
        'desc',
    ];

    // Relasi ke tabel room
    public function room()
    {
        return $this->belongsTo(Room::class, 'id_room', 'id_room');
    }

    // Relasi ke tabel status
    public function status()
    {
        return $this->belongsTo(StatusRapat::class, 'id_status', 'id_status');
    }

    // app/Models/Rapat.php
    public function pengaju()
    {
        return $this->belongsTo(User::class, 'id_user_pengaju', 'id_user');
    }


    public function absensi()
    {
        return $this->hasMany(Absensi::class, 'id_rapat', 'id_rapat');
    }

    // Relasi dengan peserta rapat
    public function peserta()
    {
        return $this->hasManyThrough(
            User::class,    // Model tujuan yang ingin diakses (User)
            Absensi::class, // Model perantara (Absensi)
            'id_rapat',     // Foreign key di tabel absensi (menghubungkan ke rapat)
            'id_user',      // Foreign key di tabel absensi (menghubungkan ke user)
            'id_rapat',     // Local key di tabel rapat
            'id_user'       // Local key di tabel user
        );
    }

}
