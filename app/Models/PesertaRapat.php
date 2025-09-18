<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PesertaRapat extends Model
{
    use HasFactory;

    protected $table = 'bbws_absensi_peserta_rapat';

    protected $fillable = [
        'id_rapat',
        'id_user',
    ];
}