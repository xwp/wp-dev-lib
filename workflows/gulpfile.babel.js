import gulp from 'gulp';
import { preCheck } from './utils/pre-check';
import { getTasks } from './utils/get-tasks';

// Check Node version and workflow setup.
preCheck();

// Define default task.
gulp.task( 'default', gulp.series( getTasks() ) );
