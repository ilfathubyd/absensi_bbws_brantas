<?php

namespace App\Providers;

use App\Models\User;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Gate;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $this->registerPolicies();

        // PINDAHKAN GATE KE SINI
        Gate::define('admin-auth', function (User $user) {
            // Gunakan nama variabel $user (singular) agar lebih jelas
            return $user->id_role == 1; // Angka 1 menandakan admin
        });

        Gate::define('pic-auth', function (User $user) {
            return in_array($user->id_role, [1, 2]); // Izinkan jika role adalah Admin (1) atau PIC (2)
        });
    }
}
