import _ from 'lodash'
import moment from 'moment'

export function createTaskList(username, items = []) {

  return {
    '@context': '/api/contexts/TaskList',
    '@id': null,
    '@type': 'TaskList',
    distance: 0,
    duration: 0,
    polyline: '',
    createdAt: moment().format(),
    updatedAt: moment().format(),
    username,
    items,
  }
}

const COLORS_LIST = [
  '#213ab2',
  '#b2213a',
  '#5221b2',
  '#93c63f',
  '#b22182',
  '#3ab221',
  '#b25221',
  '#2182b2',
  '#3ab221',
  '#9c21b2',
  '#c63f4f',
  '#b2217f',
  '#82b221',
  '#5421b2',
  '#3f93c6',
  '#21b252',
  '#c6733f'
]

export const integerToColor = value => COLORS_LIST[(value % COLORS_LIST.length)]

export function groupLinkedTasks(tasks) {

  const tasksWithPreviousOrNext = _.filter(tasks, t => t.previous || t.next)

  const lookup = (groups, task) => {
    return _.find(groups, (tasks) => _.includes(tasks, task.id)) || [ task.id ]
  }

  const groups = {}
  while (tasksWithPreviousOrNext.length > 0) {
    const task = tasksWithPreviousOrNext.shift()

    groups[task['@id']] = lookup(groups, task)

    if (task.next) {
      const nextTask = _.find(tasksWithPreviousOrNext, t => t['@id'] === task.next)
      if (nextTask) {
        groups[task['@id']].push(nextTask.id)
        groups[nextTask['@id']] = groups[task['@id']].slice()
      }
    }

    if (task.previous) {
      const prevTask = _.find(tasksWithPreviousOrNext, t => t['@id'] === task.previous)
      if (prevTask) {
        groups[task['@id']].unshift(prevTask.id)
        groups[prevTask['@id']] = groups[task['@id']].slice()
      }
    }
  }

  return groups
}

export function taskComparator(a, b) {
  return a['@id'] === b['@id']
}

export function withoutTasks(state, tasks) {

  return _.differenceWith(
    state,
    _.intersectionWith(state, tasks, taskComparator),
    taskComparator
  )
}

export function removedTasks(state, tasks) {

  return _.differenceWith(
    state,
    tasks,
    taskComparator
  )
}

export function withLinkedTasks(tasks, allTasks) {

  if (!Array.isArray(tasks)) {
    tasks = [ tasks ]
  }

  const newTasks = []
  tasks.forEach(task => {
    // FIXME
    // Make it work when more than 2 tasks are linked together
    if (task.previous) {
      // If previous task is another day, will be null
      const previousTask = _.find(allTasks, t => t['@id'] === task.previous)
      if (previousTask) {
        newTasks.push(previousTask)
      }
      newTasks.push(task)
    } else if (task.next) {
      // If next task is another day, will be null
      const nextTask = _.find(allTasks, t => t['@id'] === task.next)
      newTasks.push(task)
      if (nextTask) {
        newTasks.push(nextTask)
      }
    } else {
      newTasks.push(task)
    }
  })

  return newTasks
}
