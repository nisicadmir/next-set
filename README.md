# next_set

Application is called NextSet.

The application be the timer for sets in the gym.

## Model

```dart
name: string
numberOfSets: int
secondsPerSet: int
shouldNotifyEndOfSet: bool
shouldNotifyEndOfBreak: bool
createdAt: date
updatedAt: date
lastUsedAt?: date
```

### Home screen

On home screen there should be a list of recently used sets, which are saved in local storage.
On home sreen we should show:

- Set name
- Number of sets
- Time per set in minutes and seconds

On home screen there should be also a button which will navigate to page where we will show list of sets. On that page there should also be a button to create new set.

### List of sets page

When we are on page of list of sets, there should be:

- list of sets with name, number of sets and time per set in minutes and seconds
- Each set should have delete and edit button

#### Creating new set/updaring set

When creating new round:

- how many rounds I want to have
- how many seconds/minutes each round should have
- how many seconds/minutes there is a break between rounds
- checkbox if there should be a notification to notify 10 seconds before the end of the round
- checkbox if there should eb a notification to notify 10 seconds before the end of the break
  There should be an input if there is a need to save the configuration, if set then save it on save button.
  We should not be able to save a set with same name or with less than 2 characters.
  There should also be a button to open the set without saving.

When
