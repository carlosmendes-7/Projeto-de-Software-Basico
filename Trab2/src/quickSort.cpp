#include <iostream>
using namespace std;

void quickSort(int input[], int left, int right) {
	
	int i = left, j = right;
	int pivo = input[(i+j)/2];
	
	while(i <= j) {
		while(input[i] < pivo)
			i++;
		while(input[j] > pivo)
			j--;
		
		if(i<= j) {
			int x = input[i];
			input[i] = input[j];
			input[j] = x;
			i++,j--;
		}
	}
	
	if(left < j)
		quickSort(input,left,j); 
	if(i < right)
		quickSort(input,i,right);
	
}



int main(int argc, char *argv[])
{
	
	int n,q;
	
	cin >> n >> q;
	
	int arr[n];
	
	for(int i = 0; i < n; i++)
		cin >> arr[i];
	
	quickSort(arr,0,n-1);
	
	
	
	for(int i = n-1,j = 0; j < q; i--,j++)
		cout << arr[i] << endl;
	
	
	
	return 0;
}