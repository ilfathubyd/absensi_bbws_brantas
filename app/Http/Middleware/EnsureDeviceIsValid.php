<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use App\Models\UserDevice;

class EnsureDeviceIsValid
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        // User rule: "Semua request API setelah login harus..." -> Strict for everyone?
        
        $token = $user->currentAccessToken();
        
        if (!$token) {
             return response()->json(['message' => 'No active token.'], 401);
        }

        // Token Name format: "device:{app_instance_id}"
        $tokenNameParts = explode(':', $token->name);
        
        if (count($tokenNameParts) < 2 || $tokenNameParts[0] !== 'device') {
            // Kita assume strict: harus format baru.
            return response()->json(['message' => 'Token invalid format for device validation.'], 401);
        }

        $tokenAppInstanceId = $tokenNameParts[1];

        // Cek DB
        $activeDevice = UserDevice::where('user_id', $user->id_user)
                                  ->where('is_active', true)
                                  ->first();

        if (!$activeDevice) {
             return response()->json(['message' => 'No active device found for this account. Please login again.'], 401);
        }

        if ($activeDevice->app_instance_id !== $tokenAppInstanceId) {
             return response()->json([
                 'message' => 'Session expired or used on another device. Token mismatch.',
                 'error_code' => 'DEVICE_TOKEN_MISMATCH'
             ], 401);
        }

        return $next($request);
    }
}
