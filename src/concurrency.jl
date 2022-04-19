struct CancellationToken end

const ConcurrencyToken = Union{Nothing, CancellationToken}

struct SpawnedTask
  ch::Channel{ConcurrencyToken}
  taskref::Ref{Task}
end

function cancel(spawned::SpawnedTask)
  task = spawned.taskref[]
  (istaskdone(task) || istaskfailed(task) || !istaskstarted(task)) && return
  put!(spawned.ch, CancellationToken())
  spawned
end

function wrap_spawned(cond, f, ch::Channel, taskref::Ref{Task})
  token::ConcurrencyToken = nothing
  while cond()
    isready(ch) && (token = take!(ch))
    token === CancellationToken() && break
    sleep(0.1)
    f()
    istaskfailed(taskref[]) && wait(taskref[])
  end
  @info "Stopping $(taskref[])."
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
