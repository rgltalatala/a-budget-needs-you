'use client';

import { useState, FormEvent } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Error } from '@/components/ui/Error';
import { DEMO_CREDENTIALS } from '@/lib/demo';
import type { ApiError } from '@/types/api';

export default function SignupPage() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const { signup, login } = useAuth();

  const validatePassword = (pwd: string): string | null => {
    if (pwd.length < 12) {
      return 'Password must be at least 12 characters';
    }
    if (!/\d/.test(pwd)) {
      return 'Password must include at least one number';
    }
    if (!/[!@#$%^&*(),.?":{}|<>]/.test(pwd)) {
      return 'Password must include at least one special character';
    }
    return null;
  };

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);

    // Client-side validation
    const passwordError = validatePassword(password);
    if (passwordError) {
      setError(passwordError);
      return;
    }

    setIsLoading(true);

    try {
      await signup({ name, email, password });
      // Navigation is handled by AuthContext
    } catch (err) {
      const apiError = err as ApiError;
      setError(
        typeof apiError.message === 'string'
          ? apiError.message
          : apiError.message?.[0] || apiError.error || 'Signup failed'
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleDemoSignIn = async () => {
    setError(null);
    setIsLoading(true);

    try {
      await login({
        email: DEMO_CREDENTIALS.email,
        password: DEMO_CREDENTIALS.password,
      });
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
            Create your account
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Or{' '}
            <Link href="/login" className="font-medium text-blue-600 hover:text-blue-500">
              sign in to your existing account
            </Link>
          </p>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          {error && <Error>{error}</Error>}
          
          <div className="space-y-4">
            <Input
              label="Name"
              type="text"
              autoComplete="name"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              disabled={isLoading}
            />
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
              autoComplete="new-password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={isLoading}
            />
            <p className="text-xs text-gray-500 mt-1">
              Must be at least 12 characters with a number and special character
            </p>
          </div>

          <div className="space-y-3">
            <Button type="submit" className="w-full" isLoading={isLoading}>
              Create account
            </Button>
            <div className="relative">
              <div className="absolute inset-0 flex items-center" aria-hidden="true">
                <div className="w-full border-t border-gray-200" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="bg-gray-50 px-2 text-gray-500">or</span>
              </div>
            </div>
            <Button
              type="button"
              variant="outline"
              className="w-full"
              onClick={handleDemoSignIn}
              disabled={isLoading}
            >
              Sign in as demo
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
