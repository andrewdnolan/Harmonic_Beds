def demarcate_section(func):
    def inner(*args, **kwargs):
        print('!'*30)
        func(*args, **kwargs)
        print('!'*30)

class solver_input_file:
    def __init__(self, Nt, dt, Nx, dx):
        self.Nt = Nt
        self.dt = dt
        self.Nx = Nx
        self.dx = dx
        print('Constructing Elmer Model')

class simulation_section:
    def __init__():
        pass

class Elmer_model:
    def __init__(self, Nt, dt, Nx, dx):
        self.Nt = Nt
        self.dt = dt
        self.Nx = Nx
        self.dx = dx
        print('Constructing Elmer Model')
