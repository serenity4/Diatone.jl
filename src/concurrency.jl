struct CancellationToken end

struct SpawnedTask
  ch::Channel{Any}
  taskref::Ref{Task}
  results::Channel{Any}
end

function cancel(spawned::SpawnedTask)
  task = spawned.taskref[]
  !istaskstarted(task) && return
  istaskdone(task) && return
  if istaskfailed(task)
    @error "Task failed: $(sprint(display, task))"
  else
    put!(spawned.ch, CancellationToken())
    wait(spawned)
  end
  spawned
end

function wrap_spawned(cond, f, ch::Channel, results::Channel)
  while cond()
    while isready(ch)
      val = take!(ch)
      val isa CancellationToken && return

      # Assume `val` is a function to execute.
      fetch, val = val
      res = try
        Base.invokelatest(val)
      catch e
        @error "Encountered an error during execution" exception = (e, Base.catch_backtrace())
        nothing
      end
      fetch && put!(results, res)
    end
    f()
    yield()
  end
end

function spawn(cond, f)
  taskref = Ref{Task}()
  #TODO: Spawn the task.
  results = Channel(Inf)
  ch = Channel(ch -> wrap_spawned(cond, f, ch, results); taskref, spawn = true)
  SpawnedTask(ch, taskref, results)
end

macro spawn(cond, ex)
  :(spawn(() -> $(esc(cond)), () -> $(esc(ex))))
end

macro spawn(ex)
  :(@spawn true $(esc(ex)))
end

function Base.wait(spawned::SpawnedTask)
  try
    wait(spawned.taskref[])
  catch e
    @error "An exception occurred while waiting for a task." exception = (e, Base.catch_backtrace())
    if !isa(e, TaskFailedException)
      @info "Cancelling running task $spawned."
      cancel(spawned)
    end
    return false
  end
  true
end

function execute(f, spawned::SpawnedTask; fetch = false)
  put!(spawned.ch, fetch => f)
  fetch && take!(spawned.results)
end

# function fetch(f, spawned::SpawnedTask)
#   execute(f, spawned; fetch = true)
#   take!(spawned.results)
# end

macro execute(target, fetch, ex)
  Meta.isexpr(fetch, :(=)) && fetch.args[1] == :fetch || error("Expected `fetch = <true|false>, got ", fetch)
  fetch = esc(fetch.args[2])
  f = :(() -> $(esc(ex)))
  if Meta.isexpr(target, :(=))
    binding, target = esc.(target.args)
    :($binding = execute($f, $target; fetch = $fetch))
  else
    target = esc(target)
    :(execute($f, $target; fetch = $fetch))
  end
end

macro execute(target, ex)
  fetch = Meta.isexpr(ex, :(=))
  :(@execute $(esc(target)) fetch = $fetch $(esc(ex)))
end

function wait_all(tasks::SpawnedTask...)
  all(wait.(tasks) for spawned in tasks)
end

task(x) = x.task::SpawnedTask
wait_all(xs...) = wait_all(task.(xs)...)

isrunning(x) = !isnothing(@atomic(x.task))

macro execute_maybe_on(target, ex)
  target = esc(target)
  ex = esc(ex)
  quote
    if isrunning($target)
      @execute $target $ex
    else
      $ex
    end
  end
end
