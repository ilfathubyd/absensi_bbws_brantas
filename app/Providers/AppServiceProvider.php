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
        Gate::define('create-user', function (User $user) {
            // Gunakan nama variabel $user (singular) agar lebih jelas
            return $user->id_role == 1; // Angka 1 menandakan admin
        });
    }
}
