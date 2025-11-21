import * as esbuild from 'esbuild'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

// Plugin to resolve bare imports to app/javascript
const resolvePlugin = {
  name: 'resolve',
  setup(build) {
    build.onResolve({ filter: /^(utilities|controllers)\// }, args => {
      return {
        path: path.resolve(__dirname, 'app/javascript', args.path + '.js')
      }
    })
  }
}

const watchMode = process.argv.includes('--watch')

const buildOptions = {
  entryPoints: ['app/javascript/application.js'],
  bundle: true,
  sourcemap: true,
  format: 'esm',
  outdir: 'app/assets/builds',
  publicPath: '/assets',
  plugins: [resolvePlugin],
  loader: {
    '.js': 'js',
    '.png': 'file',
    '.svg': 'file',
  }
}

if (watchMode) {
  const ctx = await esbuild.context(buildOptions)
  await ctx.watch()
  console.log('Watching for changes...')
} else {
  await esbuild.build(buildOptions)
}
