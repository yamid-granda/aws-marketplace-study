import conventional from '@commitlint/config-conventional';

// The Angular type list from config-conventional, plus `diagrams` for changes
// to diagrams/*.mmd and their rendered output. Add scopes here rather than
// letting them sprawl in commit messages.
const TYPES = [...conventional.rules['type-enum'][2], 'diagrams'];

export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', TYPES],

    // Subjects stay lowercase so `git log --oneline` reads consistently.
    'subject-case': [
      2,
      'never',
      ['sentence-case', 'start-case', 'pascal-case', 'upper-case'],
    ],

    // A summary line that has to wrap is a summary that has lost its point.
    // The detail belongs in the body.
    'header-max-length': [2, 'always', 100],
    'body-max-line-length': [2, 'always', 100],
  },
};