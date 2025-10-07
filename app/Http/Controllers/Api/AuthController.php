<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    use AuthorizesRequests;

    public function register(Request $request)
    {
        // 🔒 LANGKAH KEAMANAN: Periksa apakah pengguna yang login adalah admin
        // Jika bukan admin, kode akan berhenti di sini dan otomatis
        // mengembalikan response 403 Forbidden.
        $this->authorize('create-user');

        // Kode validasi Anda tetap sama
        $v = Validator::make($request->all(), [
            'username' => 'required|string|unique:users,username',
            'password' => 'required|string|min:1',
            'name' => 'required|string',
            'email' => 'nullable|email|unique:users,email',
            'phone' => 'nullable|string',
            'id_role' => 'nullable|integer',
            'gender' => 'nullable|in:Male,Female',
            'id_division' => 'nullable|integer',
            'photo' => 'nullable|image|max:2048',
        ]);

        if ($v->fails()) {
            return response()->json(['errors' => $v->errors()], 422);
        }

        $data = $v->validated();

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('photos', 'public');
            $data['photo'] = Storage::url($path);
        }

        $data['password'] = Hash::make($data['password']);

        // Pengguna baru berhasil dibuat oleh admin
        $user = User::create($data);

        // Anda mungkin tidak perlu membuat token untuk user yang baru dibuat
        // karena user ini tidak langsung login. Sesuaikan sesuai kebutuhan.
        // $token = $user->createToken('api_token')->plainTextToken;

        // Cukup kembalikan data user yang baru dibuat
        return response()->json([
            'message' => 'User created successfully by admin.',
            'user' => $user,
        ], 201);
    }

    public function login(Request $request)
    {
        $v = Validator::make($request->all(), [
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        if ($v->fails()) {
            return response()->json(['errors' => $v->errors()], 422);
        }

        $user = User::where('username', $request->username)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        // PERBAIKAN: Muat relasi dengan eager loading
        $user->load(['role', 'division']);

        $token = $user->createToken('api_token')->plainTextToken;

        // PERBAIKAN: Response yang lebih aman dan konsisten
        return response()->json([
            'token' => $token,
            'user' => [
                'id_user' => $user->id_user,
                'name' => $user->name,
                'username' => $user->username,
                'email' => $user->email,
                'phone' => $user->phone,
                'gender' => $user->gender,
                'photo' => $user->photo,
                'id_role' => $user->id_role,
                'id_division' => $user->id_division,
                // PERBAIKAN: Menggunakan relasi dan accessor yang benar
                'role' => $user->role ? $user->role->role : null,
                'division' => $user->division ? $user->division->division_name : null,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ],
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out']);
    }

    public function profile(Request $request)
    {
        // Load relasi untuk response profile yang lengkap
        $user = $request->user()->load(['role', 'division']);

        return response()->json([
            'id_user' => $user->id_user,
            'name' => $user->name,
            'username' => $user->username,
            'email' => $user->email,
            'phone' => $user->phone,
            'gender' => $user->gender,
            'photo' => $user->photo,
            'id_role' => $user->id_role,
            'id_division' => $user->id_division,
            'role' => $user->role ? $user->role->role : null,
            'division' => $user->division ? $user->division->division_name : null,
            'created_at' => $user->created_at,
            'updated_at' => $user->updated_at,
        ]);
    }

        public function getUsersWithRole(Request $request)
    {
        // 🔒 LANGKAH KEAMANAN: Pastikan hanya user yang berwenang (misal: admin)
        // yang bisa mengakses daftar pengguna ini. Anda perlu membuat Gate/Policy
        // bernama 'view-users' terlebih dahulu.
        $this->authorize('create-user');

        // Mengambil semua user dengan id_role = 2
        // 'with' digunakan untuk eager loading agar tidak terjadi N+1 problem query
        $users = User::with(['role', 'division'])
                     ->where('id_role', 2)
                     ->get();

        // Mengembalikan data user dalam format JSON
        return response()->json(['users' => $users], 200);
    }
}
