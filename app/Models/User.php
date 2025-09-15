<?php

namespace App\Models;
use Laravel\Sanctum\HasApiTokens;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;


class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens,HasFactory,Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'username', 'name', 'phone', 'gender', 'division', 'photo', 'password','email'
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

     public function division()
    {
        return $this->belongsTo(Division::class, 'id_division', 'id_division');
    }

    /**
     * Mendefinisikan relasi "belongsTo" ke model Role.
     */
    public function role()
    {
        return $this->belongsTo(Role::class, 'id_role', 'id_role');
    }

    /**
     * Mendefinisikan relasi "hasMany" ke model Rapat (sebagai pengaju).
     */
    public function rapatDiajukan()
    {
        return $this->hasMany(Rapat::class, 'id_user_pengaju', 'id');
    }
}
