export type CandidateId = 'joseph' | 'zoe' | 'anna' | 'nata' | 'chelsea';

export interface Candidate {
  id: CandidateId;
  name: string;
  displayName: string;
  number: number;
  tagline: string;
  vision: string;
  mission: string[];
  avatarColor: string;
  photoUrl?: string;
}

export interface CandidateTally {
  candidate_id: CandidateId;
  name: string;
  display_name: string;
  number: number;
  tagline: string;
  avatar_color: string;
  votes: number;
  percentage: number;
}

export interface VoteSummaryResponse {
  total_votes: number;
  results: CandidateTally[];
  timestamp: string;
}

export interface VoterVerificationState {
  isVerified: boolean;
  email: string | null;
  verificationToken: string | null;
  hasVoted: boolean;
}
