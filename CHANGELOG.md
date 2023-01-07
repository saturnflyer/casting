## Unreleased

## 1.0.2

- Allow use of Casting::Enum.enum
- Remove unused local variable in enum.
- Added CODE_OF_CONDUCT.md

## 1.0.1

- Fix to properly include Enum files
- 1.0.0 actually dropped 2.6 and below.
- Fix changelog which had 0.7.3 notes that are actually 1.0 notes

## 1.0.0

- Drop Ruby 2.5 and below
- Add Casting::Enum to return enumerators which apply a set of behaviors
- Remove Casting::PreparedDelegation class and move all features into Casting::Delegation

## 0.7.2 2016-07-28

- Return defined __delegates__ or empty array, allowing frozen client objects.
  Previous implementation raised an error when accessing uninitialized collection
  of __delegates__
