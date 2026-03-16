import { describe, test, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import LoginPage from './page';

const mockLogin = vi.fn();

vi.mock('@/contexts/AuthContext', () => ({
  useAuth: () => ({ login: mockLogin }),
}));

describe('LoginPage', () => {
  beforeEach(() => {
    mockLogin.mockReset();
  });

  test('renders sign in form with email and password inputs', () => {
    render(<LoginPage />);
    expect(screen.getByRole('heading', { name: /sign in to your account/i })).toBeInTheDocument();
    expect(screen.getByLabelText(/email address/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /^sign in$/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /default demo/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /family of 4 demo/i })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /forgot password\?/i })).toHaveAttribute('href', '/forgot-password');
  });

  test('calls login with email and password on submit', async () => {
    mockLogin.mockResolvedValue(undefined);
    render(<LoginPage />);
    fireEvent.change(screen.getByLabelText(/email address/i), { target: { value: 'test@example.com' } });
    fireEvent.change(screen.getByLabelText(/password/i), { target: { value: 'password123' } });
    fireEvent.click(screen.getByRole('button', { name: /^sign in$/i }));
    expect(mockLogin).toHaveBeenCalledWith({ email: 'test@example.com', password: 'password123' });
  });

  test('calls login with default demo credentials when Default demo is clicked', async () => {
    mockLogin.mockResolvedValue(undefined);
    render(<LoginPage />);
    fireEvent.click(screen.getByRole('button', { name: /default demo/i }));
    expect(mockLogin).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'SeedPassword1!',
    });
  });

  test('calls login with family demo credentials when Family of 4 demo is clicked', async () => {
    mockLogin.mockResolvedValue(undefined);
    render(<LoginPage />);
    fireEvent.click(screen.getByRole('button', { name: /family of 4 demo/i }));
    expect(mockLogin).toHaveBeenCalledWith({
      email: 'mother@demo.com',
      password: 'SeedPassword1!',
    });
  });

  test('shows error when login rejects', async () => {
    mockLogin.mockRejectedValue({ message: 'Invalid credentials' });
    render(<LoginPage />);
    fireEvent.change(screen.getByLabelText(/email address/i), { target: { value: 'bad@example.com' } });
    fireEvent.change(screen.getByLabelText(/password/i), { target: { value: 'wrong' } });
    fireEvent.click(screen.getByRole('button', { name: /^sign in$/i }));
    expect(await screen.findByText(/invalid credentials/i)).toBeInTheDocument();
  });
});
