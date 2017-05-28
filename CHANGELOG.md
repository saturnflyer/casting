## 0.7.3

- Add Casting::Enum to return enumerators which apply a set of behaviors
- Remove Casting::PreparedDelegation class and move all features into Casting::Delegation

## 0.7.2 2016-07-28

- Return defined __delegates__ or empty array, allowing frozen client objects.
  Previous implementation raised an error when accessing uninitialized collection
  of __delegates__
