'use client';

import { useState, FormEvent, Suspense, useEffect } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Error } from '@/components/ui/Error';
import { authApi } from '@/lib/api';
import type { ApiError } from '@/types/api';

function validatePassword(pwd: string): string | null {
  if (pwd.length < 12) return 'Password must be at least 12 characters';
  if (!/\d/.test(pwd)) return 'Password must include at least one number';
  if (!/[!@#$%^&*(),.?":{}|<>]/.test(pwd)) return 'Password must include at least one special character';
  return null;
}

function SetNewPasswordForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const token = searchParams.get('token');

  const [password, setPassword] = useState('');
  const [passwordConfirmation, setPasswordConfirmation] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    if (!token || token.trim() === '') {
      setError('Invalid or missing reset link. Please request a new one from the sign-in page.');
    }
  }, [token]);

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    if (!token?.trim()) return;

    const passwordError = validatePassword(password);
    if (passwordError) {
      setError(passwordError);
      return;
    }
    if (password !== passwordConfirmation) {
      setError('Passwords do not match');
      return;
    }

    setIsLoading(true);
    try {
      await authApi.resetPassword({
        reset_token: token,
        password,
        password_confirmation: passwordConfirmation,
      });
      setSuccess(true);
      setTimeout(() => router.push('/login'), 2000);
    } catch (err) {
      const apiError = err as ApiError;
      setError(
        typeof apiError.message === 'string'
          ? apiError.message
          : apiError.message?.[0] || apiError.error || 'Failed to set new password'
      );
    } finally {
      setIsLoading(false);
    }
  };

  if (success) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-md w-full text-center space-y-4">
          <div className="rounded-md bg-green-50 p-4 text-sm text-green-800">
            Password updated. Redirecting you to sign in...
          </div>
          <Link href="/login" className="text-blue-600 hover:text-blue-500 font-medium">
            Sign in
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Create new password
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Enter your new password below. Use at least 12 characters with a number and special character.
          </p>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          {error && <Error>{error}</Error>}

          <div className="space-y-4">
            <Input
              label="New password"
              type="password"
              autoComplete="new-password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={isLoading || !token}
              minLength={12}
            />
            <Input
              label="Confirm new password"
              type="password"
              autoComplete="new-password"
              required
              value={passwordConfirmation}
              onChange={(e) => setPasswordConfirmation(e.target.value)}
              disabled={isLoading || !token}
              minLength={12}
            />
          </div>

          <div className="space-y-3">
            <Button
              type="submit"
              className="w-full"
              isLoading={isLoading}
              disabled={!token?.trim()}
            >
              Set new password
            </Button>
            <p className="text-center text-sm text-gray-600">
              <Link href="/login" className="font-medium text-blue-600 hover:text-blue-500">
                Back to sign in
              </Link>
            </p>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function SetNewPasswordPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
          <p className="text-gray-600">Loading...</p>
        </div>
      }
    >
      <SetNewPasswordForm />
    </Suspense>
  );
}
