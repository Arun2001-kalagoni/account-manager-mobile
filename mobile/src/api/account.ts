import { authGet } from './client';

export type Line = { name: string; phoneNumber: string; plan: string; dataUsedGb: number; dataLimitGb: number };
export type AccountSummary = { name: string; email: string; balanceDue: number; dueDate: string; lines: Line[] };

export const getAccountSummary = () => authGet<AccountSummary>('/api/account/summary');
