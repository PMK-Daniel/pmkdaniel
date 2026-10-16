// Shared in-memory fallback store for development & testing
export interface OtpData {
  code: string;
  expires: number;
}

export interface BallotEntry {
  candidate_id: string;
  created_at: string;
}

export const globalStore = global as unknown as {
  mockOtpStore?: Map<string, OtpData>;
  mockVoterRegistry?: Set<string>;
  mockBallots?: BallotEntry[];
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
