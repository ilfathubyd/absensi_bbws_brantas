<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Absensi extends Model
{
    protected $table = 'absensi';

    public $timestamps = false;

    protected $fillable = [
        'id_rapat', 'id_user', 'foto', 'latitude', 'longitude', 'waktu_absen', 'status',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'id_user');
    }

    public function rapat()
    {
        return $this->belongsTo(Rapat::class, 'id_rapat');
    }
}
