import { Candidate } from '@/types/voting';
import { CANDIDATES } from './candidates';

// Shared in-memory fallback store for development & testing
export interface OtpData {
  code: string;
  expires: number;
}

export interface BallotEntry {
  candidate_id: string;
  created_at: string;
}

export interface VoterDetailEntry {
  email: string;
  email_hash: string;
  candidate_id: string;
  candidate_name: string;
  voted_at: string;
}

export const globalStore = global as unknown as {
  mockOtpStore?: Map<string, OtpData>;
  mockVoterRegistry?: Set<string>;
  mockBallots?: BallotEntry[];
  mockVoterDetails?: VoterDetailEntry[];
  customCandidates?: Candidate[];
};

if (!globalStore.mockOtpStore) {
  globalStore.mockOtpStore = new Map<string, OtpData>();
}
if (!globalStore.mockVoterRegistry) {
  globalStore.mockVoterRegistry = new Set<string>();
}
if (!globalStore.mockBallots) {
  globalStore.mockBallots = [];
}
if (!globalStore.mockVoterDetails) {
  globalStore.mockVoterDetails = [];
}
if (!globalStore.customCandidates) {
  globalStore.customCandidates = [...CANDIDATES];
}
