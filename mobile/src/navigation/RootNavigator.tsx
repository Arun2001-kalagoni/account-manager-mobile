import { ActivityIndicator, View } from 'react-native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { AccountSummary } from '../api/account';
import { useAuth } from '../auth/AuthContext';
import AccountScreen from '../screens/AccountScreen';
import HomeScreen from '../screens/HomeScreen';
import LoginScreen from '../screens/LoginScreen';
import { colors } from '../theme/theme';

export type RootStackParamList = {
  Login: undefined;
  Home: undefined;
  Account: { summary: AccountSummary };
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function RootNavigator() {
  const { status } = useAuth();

  if (status === 'loading') {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator color={colors.primary} />
      </View>
    );
  }

  // Signed-out users only ever see the login stack; signed-in users only see the app stack.
  return (
    <Stack.Navigator>
      {status === 'signedIn' ? (
        <>
          <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'Home' }} />
          <Stack.Screen name="Account" component={AccountScreen} options={{ title: 'My account' }} />
        </>
      ) : (
        <Stack.Screen name="Login" component={LoginScreen} options={{ headerShown: false }} />
      )}
    </Stack.Navigator>
  );
}
