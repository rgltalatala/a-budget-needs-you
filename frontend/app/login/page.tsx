'use client';

import { useState, FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Error } from '@/components/ui/Error';
import { DEMO_OPTIONS } from '@/lib/demo';
import type { ApiError } from '@/types/api';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const { login } = useAuth();
  const router = useRouter();

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    setIsLoading(true);

    try {
      await login({ email, password });
      // Navigation is handled by AuthContext
    } catch (err) {
      const apiError = err as ApiError;
      setError(
        typeof apiError.message === 'string'
          ? apiError.message
          : apiError.message?.[0] || apiError.error || 'Login failed'
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleDemoSignIn = async (email: string, password: string) => {
    setError(null);
    setIsLoading(true);

    try {
      await login({ email, password });
    } catch (err) {
      const apiError = err as ApiError;
      setError(
        typeof apiError.message === 'string'
          ? apiError.message
          : apiError.message?.[0] || apiError.error || 'Demo sign in failed'
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Sign in to your account
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Or{' '}
            <Link href="/signup" className="font-medium text-blue-600 hover:text-blue-500">
              create a new account
            </Link>
          </p>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          {error && <Error>{error}</Error>}
          
          <div className="space-y-4">
            <Input
              label="Email address"
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={isLoading}
            />
            <Input
              label="Password"
              type="password"
              autoComplete="current-password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={isLoading}
            />
            <div className="flex justify-end">
              <Link
                href="/forgot-password"
                className="text-sm text-blue-600 hover:text-blue-500"
              >
                Forgot password?
              </Link>
            </div>
          </div>

          <div className="space-y-3">
            <Button type="submit" className="w-full" isLoading={isLoading}>
              Sign in
            </Button>
            <div className="relative">
              <div className="absolute inset-0 flex items-center" aria-hidden="true">
                <div className="w-full border-t border-gray-200" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="bg-gray-50 px-2 text-gray-500">or try a demo</span>
              </div>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              {DEMO_OPTIONS.map((demo) => (
                <Button
                  key={demo.id}
                  type="button"
                  variant="outline"
                  className="w-full"
                  onClick={() => handleDemoSignIn(demo.email, demo.password)}
                  disabled={isLoading}
                >
                  {demo.label}
                </Button>
              ))}
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}
