struct CancellationToken end

const ConcurrencyToken = Union{Nothing, CancellationToken}

struct SpawnedTask
  ch::Channel{ConcurrencyToken}
  taskref::Ref{Task}
end

function cancel(spawned::SpawnedTask)
  task = spawned.taskref[]
  (istaskdone(task) || !istaskstarted(task)) && return
  # Unwrap the error.
  istaskfailed(task) && wait(task)
  put!(spawned.ch, CancellationToken())
  spawned
end

function wrap_spawned(cond, f, ch::Channel, taskref::Ref{Task})
  token::ConcurrencyToken = nothing
  while cond()
    isready(ch) && (token = take!(ch))
    if token === CancellationToken()
      @info "Stopping $(taskref[])."
      break
    end
    f()
  end
end

function spawn(cond, f)
  taskref = Ref{Task}()
  #TODO: Spawn the task.
  ch = Channel{ConcurrencyToken}(ch -> wrap_spawned(cond, f, ch, taskref); taskref)#, spawn = true)
  SpawnedTask(ch, taskref)
end

macro spawn(cond, ex)
  :(spawn(() -> $(esc(cond)), () -> $(esc(ex))))
end

macro spawn(ex)
  :(@spawn true $(esc(ex)))
end

Base.wait(spawned::SpawnedTask) = wait(spawned.taskref[])
