import qiskit 

from qiskit import QuantumCircuit
from qiskit.quantum_info import Statevector
from qiskit_aer import AerSimulator

qc1 = QuantumCircuit(11, 2)

qc1.cx(0, 3)
qc1.cx(0, 6)

qc1.h(0)
qc1.h(3)
qc1.h(6)

qc1.z(0)

qc1.cx(0, 1)
qc1.cx(0, 2)

qc1.cx(3, 4)
qc1.cx(3, 5)

qc1.cx(6, 7)
qc1.cx(6, 8)

qc1.x(5)

qc1.x(9)
qc1.x(10)

qc1.h(9)
qc1.h(10)

qc1.cx(9, 0)
qc1.cx(9, 1)
qc1.cx(9, 2)
qc1.cx(9, 3)
qc1.cx(9, 4)
qc1.cx(9, 5)
qc1.cx(10, 3)
qc1.cx(10, 4)
qc1.cx(10, 5)
qc1.cx(10, 6)
qc1.cx(10, 7)
qc1.cx(10, 8)

qc1.measure(9, 0)
qc1.measure(10, 1)

print(qc1)
