'use client';

import { useState, FormEvent } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Error } from '@/components/ui/Error';
import { authApi } from '@/lib/api';
import type { ApiError } from '@/types/api';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    setMessage(null);
    setIsLoading(true);

    try {
      const result = await authApi.requestPasswordReset(email.trim());
      if (result.reset_token) {
        router.push(`/forgot-password/set-new?token=${encodeURIComponent(result.reset_token)}`);
        return;
      }
      setMessage(
        result.message || 'If an account exists for that email, you can use the link we sent to set a new password.'
      );
    } catch (err) {
      const apiError = err as ApiError;
      setError(
        typeof apiError.message === 'string'
          ? apiError.message
          : apiError.message?.[0] || apiError.error || 'Request failed'
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
            Forgot password?
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Enter your email and we&apos;ll let you set a new password.
          </p>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          {error && <Error>{error}</Error>}
          {message && (
            <div className="rounded-md bg-green-50 p-4 text-sm text-green-800">
              {message}
            </div>
          )}

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
          </div>

          <div className="space-y-3">
            <Button type="submit" className="w-full" isLoading={isLoading}>
              Continue
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
