<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Rapat extends Model
{
    use HasFactory;

    /**
     * Nama tabel yang terhubung dengan model.
     *
     * @var string
     */
    protected $table = 'rapat';

    /**
     * Primary key untuk model ini.
     *
     * @var string
     */
    protected $primaryKey = 'id_rapat';

    /**
     * Atribut yang dapat diisi secara massal.
     *
     * @var array
     */
    protected $fillable = [
        'id_room',
        'id_cabang',
        'judul',
        'waktu_start',
        'waktu_end',
        'id_status',
        'id_user_pengaju',
        'desc',
    ];

    /**
     * Mendefinisikan relasi "belongsTo" ke model User.
     */
    public function userPengaju()
    {
        return $this->belongsTo(User::class, 'id_user_pengaju', 'id');
    }

    /**
     * Mendefinisikan relasi "belongsTo" ke model Room.
     */
    public function room()
    {
        return $this->belongsTo(Room::class, 'id_room', 'id_room');
    }

    /**
     * Mendefinisikan relasi "belongsTo" ke model Cabang.
     */
    public function cabang()
    {
        return $this->belongsTo(Cabang::class, 'id_cabang', 'id_cabang');
    }

    /**
     * Mendefinisikan relasi "belongsTo" ke model StatusRapat.
     */
    public function statusRapat()
    {
        return $this->belongsTo(StatusRapat::class, 'id_status', 'id_status');
    }
}