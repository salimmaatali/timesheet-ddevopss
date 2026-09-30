package tn.esprit.spring.services;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import tn.esprit.spring.entities.Role;
import tn.esprit.spring.entities.User;
import tn.esprit.spring.repository.UserRepository;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Optional;

// Test unitaire avec Mockito : le repository est simule (@Mock),
// aucune base de donnees ni contexte Spring n'est demarre.
@ExtendWith(MockitoExtension.class)
class UserServiceImplMockTest {

	@Mock
	UserRepository userRepository;

	@InjectMocks
	UserServiceImpl userService;

	User user = new User("f1", "l1", new Date(), Role.ADMINISTRATEUR);

	List<User> listUsers = new ArrayList<User>() {
		{
			add(new User("f2", "l2", new Date(), Role.ADMINISTRATEUR));
			add(new User("f3", "l3", new Date(), Role.ADMINISTRATEUR));
		}
	};

	@Test
	void testRetrieveUser() {
		Mockito.when(userRepository.findById(Mockito.anyLong())).thenReturn(Optional.of(user));
		User user1 = userService.retrieveUser("2");
		Assertions.assertNotNull(user1);
		Assertions.assertEquals("l1", user1.getLastName());
	}

	@Test
	void testRetrieveUserNotFound() {
		Mockito.when(userRepository.findById(Mockito.anyLong())).thenReturn(Optional.empty());
		Assertions.assertNull(userService.retrieveUser("99"));
	}

	@Test
	void testRetrieveAllUsers() {
		Mockito.when(userRepository.findAll()).thenReturn(listUsers);
		Assertions.assertEquals(2, userService.retrieveAllUsers().size());
	}

	@Test
	void testAddUser() {
		Mockito.when(userRepository.save(Mockito.any(User.class))).thenReturn(user);
		User added = userService.addUser(user);
		Assertions.assertEquals("f1", added.getFirstName());
		Mockito.verify(userRepository).save(user);
	}

	@Test
	void testUpdateUser() {
		Mockito.when(userRepository.save(Mockito.any(User.class))).thenReturn(user);
		Assertions.assertNotNull(userService.updateUser(user));
	}

	@Test
	void testDeleteUser() {
		userService.deleteUser("5");
		Mockito.verify(userRepository).deleteById(5L);
	}
}
