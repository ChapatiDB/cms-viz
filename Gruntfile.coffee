path = require 'path'

# Build configurations.
module.exports = (grunt) ->
  grunt.initConfig
    # Deletes Compiled script directory
    # These directories should be deleted before subsequent builds.
    # These directories are not committed to source control.
    clean:
      working:
        scripts: [
          './dist/*'
        ]
      
    # Compile CoffeeScript (.coffee) files to JavaScript (.js).
    coffee:
      src:
        files: [
          cwd: './coffee'
          src: '**/*.coffee'
          dest: './dist'
          expand: true
          ext: '.js'
        ]
        # options:
          # Don't include a surrounding Immediately-Invoked Function Expression (IIFE) in the compiled output.
          # For more information on IIFEs, please visit http://benalman.com/news/2010/11/immediately-invoked-function-expression/
          # bare: true

    # Sets up file watchers and runs tasks when watched files are changed.
    watch:
      coffee:
        files: './coffee/**'
        tasks: [
          'coffee:src'
        ]

  # Register grunt tasks supplied by grunt-contrib-*.
  # Referenced in package.json.
  # https://github.com/gruntjs/grunt-contrib
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  # Compiles the app with non-optimized build settings.
  # Enter the following command at the command line to execute this build task:
  # grunt
  grunt.registerTask 'default', [
    'coffee:src'
  ]


  # Compiles the app with non-optimized build settings and watches changes.
  # Enter the following command at the command line to execute this build task:
  # grunt dev
  grunt.registerTask 'dev', [
    'coffee:src'
    'watch'
  ]